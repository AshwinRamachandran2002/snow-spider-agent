import argparse
import contextlib
import io
import pickle
import socket

from IPython.core.interactiveshell import InteractiveShell


class InteractivePythonExecutor:
    def __init__(self):
        self.kernel_initialized = False
        self.shell = None
        self.execution_count = 0
        self.namespace = {}

    def initialize_kernel(self):
        if not self.kernel_initialized:
            self.shell = InteractiveShell.instance()
            self.kernel_initialized = True
            self.execution_count = 0

    def terminate_kernel(self):
        if self.kernel_initialized:
            self.namespace.clear()  # Clear the namespace
            self.kernel_initialized = False
            self.shell = None

    def execute(self, code):
        if not self.kernel_initialized:
            self.initialize_kernel()
        self.execution_count += 1

        try:
            output_stream = io.StringIO()
            with contextlib.redirect_stdout(output_stream):
                exec(code, self.namespace)
            stdout_output = output_stream.getvalue()
            output = stdout_output.strip()

        except SystemExit:
            # The user called `exit()`; treat it like a kernel termination
            self.terminate_kernel()
            output = "Kernel terminated."

        except Exception as e:
            output = f"{type(e).__name__}: {e}"

        return f"{output.strip()}"


# Server to maintain runtime
class AgentIPythonServer:
    def __init__(self, host="localhost", port=9999):
        self.host = host
        self.port = port
        self.agent = InteractivePythonExecutor()

    def start(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
            server_socket.bind((self.host, self.port))
            server_socket.listen(1)
            print(f"Server started on {self.host}:{self.port}")
            while True:
                conn, addr = server_socket.accept()
                with conn:
                    data = conn.recv(4096)
                    if not data:
                        continue
                    command = pickle.loads(data)
                    if command.get("terminate_kernel", False):
                        self.agent.terminate_kernel()
                        response = "Kernel terminated."
                    else:
                        code = command.get("code", "")
                        response = self.agent.execute(code)
                    conn.sendall(pickle.dumps(response))


def main():
    parser = argparse.ArgumentParser(
        description="Start an iPython server for the AI agent."
    )
    parser.add_argument(
        "--host",
        default="localhost",
        help="Host/IP address to bind the iPython server.",
    )
    parser.add_argument(
        "--port", type=int, default=9999, help="Port number to bind the iPython server."
    )
    args = parser.parse_args()

    server = AgentIPythonServer(host=args.host, port=args.port)
    server.start()


if __name__ == "__main__":
    main()
