use serde::Deserialize;
use serde_json::{json, Value};
use std::env;
use std::io::{BufRead, BufReader, Write};
use std::net::Shutdown;
use std::os::unix::net::UnixStream;
use std::process;

#[derive(Deserialize)]
struct ApiResponse<T> {
    result: Option<T>,
    error: Option<ApiError>,
}

#[derive(Deserialize)]
struct ApiError {
    code: String,
    message: String,
}

#[derive(Deserialize)]
struct SnapshotResult {
    snapshot: Snapshot,
}

#[derive(Deserialize)]
struct Snapshot {
    focused_workspace_id: String,
    workspaces: Vec<Workspace>,
    tabs: Vec<Tab>,
    agents: Vec<Agent>,
}

#[derive(Deserialize)]
struct Workspace {
    workspace_id: String,
}

#[derive(Deserialize)]
struct Tab {
    tab_id: String,
    workspace_id: String,
}

#[derive(Deserialize)]
struct Agent {
    pane_id: String,
}

enum TargetKind {
    Tab,
    Workspace,
    Agent,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("herdr-select: {err}");
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let mut args = env::args().skip(1);
    let first = args
        .next()
        .ok_or_else(|| "expected [tab|workspace|agent] number 1-9".to_string())?;

    let (kind, target_arg) = match first.as_str() {
        "tab" => (TargetKind::Tab, args.next()),
        "workspace" => (TargetKind::Workspace, args.next()),
        "agent" => (TargetKind::Agent, args.next()),
        // Backward-compatible form: herdr-select 1 == herdr-select tab 1.
        _ => (TargetKind::Tab, Some(first)),
    };

    let target = target_arg
        .ok_or_else(|| "expected number 1-9".to_string())?
        .parse::<usize>()
        .map_err(|_| "expected tab number 1-9".to_string())?;

    if !(1..=9).contains(&target) {
        return Err("expected number 1-9".to_string());
    }

    let socket_path = env::var("HERDR_SOCKET_PATH")
        .map_err(|_| "HERDR_SOCKET_PATH is not set; this must run inside Herdr".to_string())?;

    let snapshot: SnapshotResult = request(
        &socket_path,
        json!({"id":"tab_select_snapshot","method":"session.snapshot","params":{}}),
    )?;

    match kind {
        TargetKind::Tab => {
            let tabs: Vec<&Tab> = snapshot
                .snapshot
                .tabs
                .iter()
                .filter(|tab| tab.workspace_id == snapshot.snapshot.focused_workspace_id)
                .collect();

            let tab = tabs
                .get(target - 1)
                .ok_or_else(|| format!("tab {target} not found in current workspace"))?;

            let _: Value = request(
                &socket_path,
                json!({
                    "id":"herdr_select_tab_focus",
                    "method":"tab.focus",
                    "params":{"tab_id": tab.tab_id},
                }),
            )?;
        }
        TargetKind::Workspace => {
            let workspace = snapshot
                .snapshot
                .workspaces
                .get(target - 1)
                .ok_or_else(|| format!("workspace {target} not found"))?;

            let _: Value = request(
                &socket_path,
                json!({
                    "id":"herdr_select_workspace_focus",
                    "method":"workspace.focus",
                    "params":{"workspace_id": workspace.workspace_id},
                }),
            )?;
        }
        TargetKind::Agent => {
            let agent = snapshot
                .snapshot
                .agents
                .get(target - 1)
                .ok_or_else(|| format!("agent {target} not found"))?;

            let _: Value = request(
                &socket_path,
                json!({
                    "id":"herdr_select_agent_focus",
                    "method":"agent.focus",
                    "params":{"target": agent.pane_id},
                }),
            )?;
        }
    }

    Ok(())
}

fn request<T: for<'de> Deserialize<'de>>(socket_path: &str, request: Value) -> Result<T, String> {
    let mut stream = UnixStream::connect(socket_path)
        .map_err(|err| format!("failed to connect to Herdr socket {socket_path}: {err}"))?;

    serde_json::to_writer(&mut stream, &request)
        .map_err(|err| format!("failed to encode request: {err}"))?;
    stream
        .write_all(b"\n")
        .map_err(|err| format!("failed to write request: {err}"))?;
    stream
        .flush()
        .map_err(|err| format!("failed to flush request: {err}"))?;
    stream
        .shutdown(Shutdown::Write)
        .map_err(|err| format!("failed to close request stream: {err}"))?;

    let mut socket = BufReader::new(stream);
    let mut line = String::new();
    socket
        .read_line(&mut line)
        .map_err(|err| format!("failed to read response: {err}"))?;

    if line.is_empty() {
        return Err("Herdr socket closed before responding".to_string());
    }

    let response: ApiResponse<T> = serde_json::from_str(&line)
        .map_err(|err| format!("failed to decode response: {err}: {line}"))?;

    match (response.result, response.error) {
        (Some(result), None) => Ok(result),
        (_, Some(error)) => Err(format!("Herdr API error {}: {}", error.code, error.message)),
        (None, None) => Err("Herdr response had no result or error".to_string()),
    }
}
