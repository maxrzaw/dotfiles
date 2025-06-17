#!/usr/bin/env python3
import os, time, subprocess, glob, logging
import datetime

# Configure logging
log_file = f"/tmp/aws_token_daemon_{os.environ.get('USER', 'unknown')}.log"
logging.basicConfig(
    filename=log_file,
    level=logging.WARNING,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

USER = os.environ.get("USER", "unknown")
CACHE_FILE = f"/tmp/aws_token_status_{USER}"
SSO_CACHE_DIR = os.path.expanduser("~/.aws/sso/cache/")
THRESHOLD = 2 * 3600  # 2 hours
INTERVAL = 30  # seconds

logging.info(f"Starting AWS token daemon for user {USER}")
logging.info(f"Cache file: {CACHE_FILE}")
logging.info(f"SSO cache directory: {SSO_CACHE_DIR}")
logging.info(f"Threshold: {THRESHOLD} seconds, Interval: {INTERVAL} seconds")

def get_latest_cache_file():
    files = glob.glob(os.path.join(SSO_CACHE_DIR, "*"))
    if not files:
        logging.warning("No SSO cache files found")
        return None
    latest = max(files, key=os.path.getmtime)
    logging.debug(f"Latest SSO cache file: {latest}")
    return latest

def check_valid():
    try:
        logging.debug("Checking token validity with aws sts get-caller-identity")
        subprocess.check_call(
            ["aws", "sts", "get-caller-identity"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        logging.info("Token is valid")
        return True
    except Exception as e:
        logging.warning(f"Token validation failed: {str(e)}")
        return False

logging.info("Starting main daemon loop")

try:
    while True:
        now = time.time()
        status = "not_logged_in"
        logging.debug(f"Checking token at {datetime.datetime.now().isoformat()}")

        cache_file = get_latest_cache_file()
        if cache_file:
            last_mod = os.path.getmtime(cache_file)
            mod_time_str = datetime.datetime.fromtimestamp(last_mod).isoformat()
            age = now - last_mod
            logging.debug(f"SSO cache last modified: {mod_time_str} (age: {age:.1f}s)")

            if age < THRESHOLD:
                if check_valid():
                    status = "valid"
                else:
                    logging.info("Token invalid, attempting login")
                    try:
                        subprocess.run(["aws", "sso", "login"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        status = "valid" if check_valid() else "expired"
                    except Exception as e:
                        logging.error(f"AWS SSO login failed: {str(e)}")
                        status = "expired"
            else:
                logging.warning(f"SSO cache too old: {age:.1f}s > {THRESHOLD}s threshold")
        else:
            logging.warning("No SSO cache file found")

        logging.info(f"Writing status to cache: {status}")
        with open(CACHE_FILE, "w") as f:
            f.write(status)

        logging.debug(f"Sleeping for {INTERVAL} seconds")
        time.sleep(INTERVAL)
except Exception as e:
    logging.error(f"Daemon crashed: {str(e)}")
    raise
