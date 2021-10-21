# Cluster Setup

## Create an SSH key

This is probably my favorite place on the Internet to look this up:

<https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair>

## Onboarding a node

Add the node to the `inventory.yml` file.

Log in to the Pi to configure the network and user account for the first time.

Use `ssh-copy-id` to copy the SSH key to the system.

Ongoing remediation can be done with `make network`:

```
make network
```

To install and configure the base software on the Pi:

```
make setup
```

Firewall setup (though, I never really got this working right):

```
make firewall
```

## Registration

After setup of control plane node, run:

```
sudo kubeadm init
sudo kubeadm token create --print-join-command
```

Then use the join command on workers.

## Management

The cluster can be hard rebooted with `make reboot`:

```
make reboot
```

A rolling reboot can be done with `make rolling-reboot`:

```
make rolling-reboot
```

All nodes can be shut down at once with `make shutdown`:

```
make shutdown
```
