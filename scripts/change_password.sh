#!/usr/bin/expect -f

set timeout 10
set new_password "StudX@VPS2025!"

spawn ssh root@167.71.48.249

expect {
    "password:" {
        send "4fa70917ad5a38b508f7ed4930\r"
    }
}

expect {
    "Current password:" {
        send "4fa70917ad5a38b508f7ed4930\r"
    }
    "(current) UNIX password:" {
        send "4fa70917ad5a38b508f7ed4930\r"
    }
}

expect {
    "New password:" {
        send "$new_password\r"
    }
    "Enter new UNIX password:" {
        send "$new_password\r"
    }
}

expect {
    "Retype new password:" {
        send "$new_password\r"
    }
    "Retype new UNIX password:" {
        send "$new_password\r"
    }
}

expect {
    "root@" {
        send "echo 'PASSWORD CHANGED SUCCESSFULLY'\r"
        send "exit\r"
    }
}

expect eof