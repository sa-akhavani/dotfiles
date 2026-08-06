1. change dns
2. firewall — nftables, tracked as shared/etc/nftables.conf + nftables.service
   in shared/services.txt. one declarative file, same shape as greetd/zram, so
   it diffs in git; ufw's rule database does not. baseline: drop input, accept
   established+related, accept loopback, ssh from RFC1918 only, mDNS/IPP on-link.
   NOT a reason to disable sshd — it is already key-only, no root, AllowUsers ali.
   gotcha: docker bypasses it. published ports arrive as FORWARD after DNAT, not
   INPUT, so -p 8080:80 stays reachable from the LAN whatever the ruleset says.
   needs a DOCKER-USER rule or binding published ports to 127.0.0.1.
