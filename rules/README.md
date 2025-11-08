# Rule Sources

Place each sing-box rule-set JSON file in this directory (sub-folders allowed).  
Every `*.json` file will be compiled into a matching `.srs` file under `dist/` with the same relative path.

Keep the JSON structure aligned with the official documentation: https://sing-box.sagernet.org/configuration/rule-set/source-format/

Remember that rule-set sources describe *headless* rules, so **do not** include fields like `action` or `outbound`; those belong to the main sing-box route configuration that consumes the compiled `.srs`.
