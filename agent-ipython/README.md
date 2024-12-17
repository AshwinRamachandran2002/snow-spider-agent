# agent-ipython

`agent-ipython` is a client-server command line tool that allows you to execute Python code on a remote IPython kernel. The server maintains the kernel's state, allowing for persistent execution across multiple client requests. This tool is AI agent's Jupyter notebook equivalent, allowing agents (or you) to run Python code remotely.

## Features

- Execute Python code remotely.
- Maintain kernel state across multiple executions.
- Terminate the kernel remotely.

## Installation

```bash
# cd agent-ipython
pip install -e .
```

## Usage

### Starting the Server

To start the IPython server, run:
```bash
aipy-server --host <host> --port <port>
```
Replace `<host>` and `<port>` with your desired host and port. The default is `localhost:9999`.

### Running the Client

To execute code on the remote IPython kernel, use:
```bash
aipy "a = 1" --host <host> --port <port>
```
Replace `<host>` and `<port>` with the server's host and port. Leave them blank to use the default `localhost:9999`.

> [!NOTE]
> When you run the command above, the server will execute the code `a = 1` on the remote IPython kernel. The server will maintain the kernel's state. It's just like Jupyter notebook, but on the command line!

You can continue running code on the same kernel:
```bash
aipy "print(a + 1)"
>>> 2
```

`aipy` client also supports pipeline or input redirection:
```bash
aipy < script.py
```
```bash
echo "print('Hello, World!')" | aipy
```

> [!NOTE]
> Currently, we only support the standard output to be displayed on the client side.

### Terminating the Kernel

To terminate the remote IPython kernel, run:
```bash
aipy --host <host> --port <port> --terminate_kernel
```
Alternatively, you can use the `aipy` client to run `exit()`:
```bash
aipy "exit()" --host <host> --port <port>
```
