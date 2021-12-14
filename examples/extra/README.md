# Extra Tips and Tricks

## Frontend access for cloud machines

If you're running through the examples and you're using a cloud machine to do
so (easy way to get some minikube clusters ready), some of the examples call
for accessing your workload front-ends from your local machine's browser.

However, the kubectl port-forward will only open a port on the cloud machine
that's probably not available for you to load externally.

In order to access this from your browser, one trick that can be employed is
to use a SOCKS proxy to set up a tunnel between your local machine and your
cloud machine, as long as you have ssh connectivity. Then you can configure
your browser (here we'll show firefox) to act as if it is running directly
on your cloud machine. That will allow you to view apps from "localhost", where
localhost actually refers to your cloud machine.

First, connect to your cloud machine via ssh, and specify a `-D`, flag, which
runs the SOCKS proxy on the specified port of your workstation.

`ssh -D 2002 -i <key> <user>@<cloud_machine_ip>`

Here we'll use 2002.

With Firefox, there is an `about:config` setting that is necessary to enable to
allow you to use localhost to refer to the cloud machine, and not the workstation
that the browser is running on. Type `about:config` in your Firefox address bar
and set the following to true:

`network.proxy.allow_hijacking_localhost`

Set up your browser's proxy settings to utilize the SOCKS proxy. For the purposes
of the exercises, I like to open a new Firefox profile to sandbox these settings
from my normal browser profile with `firefox -P`.

Open `about:preferences`, and open the Settings dialog of General > Network Settings.

Choose Manual proxy configuration, and specify `localhost` for SOCKS Host, and
port `2002` for the port (or whatever port you picked for your ssh -D flag).

Finally, in your ssh console on the cloud host where you have been running your
kubectl commands, you can port forward your service to the cloud machine, as
an example for the guestbook scenario, src context:

`kubectl --context src --namespace guestbook port-forward svc/frontend 8080:80`

Now on your workstation, you should be able to type `localhost:8080` in your
address bar and see your guestbook application to make state changes!
