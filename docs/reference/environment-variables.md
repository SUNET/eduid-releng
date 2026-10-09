# Environment Variables Reference

## Purpose

Provide a concise lookup page for the main runtime variables surfaced by releng-owned start scripts.

## Source Of Truth

- `images/webapp/start-webapp.sh`
- `images/worker/start-worker.sh`
- `images/fastapi/start-fastapi.sh`
- `images/satosa_scim/start-satosa_scim.sh`
- `images/vccs/start-vccs.sh`
- `images/vccs/start-pyeleven.sh`
- `images/vccs/luna-pyeleven/entrypoint.sh`
- `images/vccs/pyeleven-gunicorn.conf.py`

## Common Variables

- `eduid_name`: required service name used by all main Python entrypoints
- `EDUID_CONFIG_NS`: optional namespace name echoed and consumed by runtime code
- `EDUID_CONFIG_YAML`: runtime config path consumed by backend code
- `base_dir`: base runtime directory, typically `/opt/eduid`
- `project_dir`: service project directory under the base dir
- `app_dir`: app directory derived from `project_dir` and `eduid_name`
- `cfg_dir`: config directory under the base dir
- `extra_sources_dir`: optional mounted source tree for development-mode extras
- `log_dir`: log directory used by Gunicorn or worker processes
- `state_dir`: runtime state directory used for pid or control-socket files

## Webapp And FastAPI Family

These scripts also surface variables such as:

- `workers`
- `worker_class`
- `worker_threads`
- `worker_timeout`
- `forwarded_allow_ips`
- `limit_request_line`
- `eduid_entrypoint` for `webapp`

`webapp`, `fastapi`, and the shared FastAPI launcher used by VCCS can also install extra packages from `${extra_sources_dir}/eduid/dev-extra-modules.txt`.

## VCCS Pyeleven Service

Normal VCCS startup also runs the pyeleven HTTP service using Debian's Python.

- `PYELEVEN_PORT`: pyeleven listener port, default `8000`
- `PYELEVEN_ARGS`: one Gunicorn argument, default `-w5` (for example, `-w1`); upstream passes this as a single quoted argument
- `GUNICORN_CMD_ARGS`: additional Gunicorn options; keep the service in the foreground and preserve releng's user and control-socket settings
- `PKCS11PIN`: HSM PIN written into runtime `/config.py`, default empty; double quotes, backslashes and line breaks are rejected because upstream does not escape them
- `state_dir`: shared runtime directory, default `/opt/eduid/run`; pyeleven uses a separate `pyeleven.ctl` control socket

The pyeleven launcher can also be invoked as `/bin/bash /start-pyeleven.sh`
after Luna configuration and certificates have been prepared. It activates the
Debian-backed venv and delegates to an unmodified upstream entrypoint. Without
arguments upstream generates `/config.py` and starts pyeleven. With arguments it
executes the supplied command from `/tmp`.

## Worker-Specific Variables

- `eduid_queue`
- `eduid_entrypoint`
- `logfile`
- `celery_args`

## SATOSA Note

`satosa_scim` does not use the extra-modules runtime install path. It follows its own startup behavior around the copied source tree and installed environment.