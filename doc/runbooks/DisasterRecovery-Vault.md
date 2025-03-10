# Vault Disaster recovery

Both the "automated" and "manual" procedures are based on the official [Vault disaster recovery procedure](https://learn.hashicorp.com/tutorials/vault/sop-restore#single-vault-cluster)

## The "automated" method

This method is based on an Ansible playbook.

1. Place the snapshot to restore in the `artifact` subdirectory, under the name `latest-vault.snapshot`.
2. Run the restoration playbook:
    ```bash
    ansible-playbook -i artifacts/vault-inventory.yml ansible-playbooks/vault-snapshot-restore.yaml
    # 【output】
    # ... truncated ...
    # paas-staging-vault-1324e-gojrj : ok=36   changed=20   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
    # paas-staging-vault-1324e-ntxuj : ok=49   changed=24   unreachable=0    failed=0    skipped=2    rescued=0    ignored=0   
    # paas-staging-vault-1324e-ribtp : ok=36   changed=20   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
    #
    ```
3. Check your Vault cluster status

## The "manual" method

### Prerequisites

- you need a snapshot (from backup for ex.) available on one of the cluster peer
- you need to perform a copy of your root-token.txt: keep it on a secure storage!
- you need to perform a copy of your unseal keys (artifacts/vault-unseal-key-*.txt): keept them on a secure storage!

### Procedure

1. Reset each member Vault storage. On each hosts:
    ```bash
    $ sudo systemctl stop vault-agent
    $ sudo systemctl stop vault-server
    $ sudo rm -rf /var/lib/vault/*
    ```

2. Now you can rebuild a new cluster. From this repository, run the following playbooks:
    ```bash
    ansible-playbook -i artifacts/vault-inventory.yml ansible-playbooks/vault-cluster-bootstrap.yaml
    ```

From now, you have a brand new fully fonctionnal Vault cluster, but it doesn't contain your data anymore.

3. From the host where a snapshot is available:
    ```bash
    sudo -iu vault
    export VAULT_TOKEN=<content of new root-token.txt>
    vault operator raft list-peers
    # 【output】
    # Node                              Address                 State       Voter
    # ----                              -------                 -----       -----
    # paas-staging-vault-addab-nvxka    194.182.170.142:8201    leader      true
    # paas-staging-vault-addab-mklsr    194.182.169.48:8201     follower    true
    # paas-staging-vault-addab-utxcg    89.145.162.86:8201      follower    true
    export VAULT_ADDR=https://<address-of-the-leader>:8200
    vault operator raft snapshot restore -force snap.snapshot

From now, your cluster contains the content of your snapshot, but it's back in sealed state.

4. Restore the original root-token and unseal key(s) you have backuped before running this procedure

5. Unseal the cluster and restart the vault-agent :
    ```bash
    ansible-playbook -i artifacts/vault-inventory.yml ansible-playbooks/vault-cluster-unseal.yaml
    # 【output】
    # ... truncated ...
    # paas-staging-vault-addab-mklsr : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    # paas-staging-vault-addab-nvxka : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    # paas-staging-vault-addab-utxcg : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    #
    ansible-playbook -i artifacts/vault-inventory.yml ansible-playbooks/vault-cluster-tls-agent.yaml
    # 【output】
    # ... truncated ...
    # paas-staging-vault-addab-mklsr : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    # paas-staging-vault-addab-nvxka : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    # paas-staging-vault-addab-utxcg : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    #
    ```
