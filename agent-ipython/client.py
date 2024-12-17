import argparse
import pickle
import socket
import sys


def main():
    parser = argparse.ArgumentParser(description="iPython client for AI agent.")
    parser.add_argument(
        "code", nargs="?", help="Code to execute in the iPython kernel."
    )
    parser.add_argument(
        "--host", default="localhost", help="Host/IP of the running iPython server."
    )
    parser.add_argument(
        "--port", type=int, default=9999, help="Port to connect to the iPython server."
    )
    parser.add_argument(
        "--terminate_kernel",
        action="store_true",
        help="Terminate the current kernel on the server.",
    )
    args = parser.parse_args()

    # If there's code coming from stdin (e.g., piping in a script), use that instead of args.code
    if not sys.stdin.isatty():
        code = sys.stdin.read()
    else:
        code = args.code

    command = {"terminate_kernel": args.terminate_kernel, "code": code if code else ""}

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client_socket:
        client_socket.connect((args.host, args.port))
        client_socket.sendall(pickle.dumps(command))
        response = pickle.loads(client_socket.recv(4096))
        print(response)


if __name__ == "__main__":
    main()
