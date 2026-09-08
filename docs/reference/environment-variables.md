# Environment Variables Reference

## Purpose

Provide a concise lookup page for the main runtime variables surfaced by releng-owned start scripts.

## Source Of Truth

- `images/webapp/start-webapp.sh`
- `images/worker/start-worker.sh`
- `images/fastapi/start-fastapi.sh`
- `images/satosa_scim/start-satosa_scim.sh`
- `images/vccs/start-fastapi.sh`

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

`webapp`, `fastapi`, and `vccs/start-fastapi.sh` can also install extra packages from `${extra_sources_dir}/eduid/dev-extra-modules.txt`.

## Worker-Specific Variables

- `eduid_queue`
- `eduid_entrypoint`
- `logfile`
- `celery_args`

## SATOSA Note

`satosa_scim` does not use the extra-modules runtime install path. It follows its own startup behavior around the copied source tree and installed environment.