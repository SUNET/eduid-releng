import os

chdir = "/"
user = "eduid"
group = "eduid"
control_socket = os.path.join(os.environ.get("state_dir", "/opt/eduid/run"), "pyeleven.ctl")