local M = {}
-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
function M.basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

return M
