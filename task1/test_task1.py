import subprocess
import os

def run_task1(args, input_data=None):
    """Executes the task1 binary with given arguments and input."""
    cmd = ["./task1"] + args
    process = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=False # Work with bytes for raw data
    )
    stdout, stderr = process.communicate(input=input_data)
    return stdout, stderr

def test_basic_vigenere():
    # 'B' subtracts 'A' (65 - 65) = shift of 1
    # 'a' (97) + 1 = 'b' (98)
    # 'A' (65) + 1 = 'B' (66)
    out, err = run_task1(["+VB"], input_data=b"abcABC")
    if out == b"bcdBCD":
        print(" [PASS] Basic shift works, abcABC => bcdBCD.")
    else:
        print(f" [FAIL] Expected b'bcdBCD', got {out}")

def test_long_key():
    # Key '+VBCD' maps to shifts: B=1, C=2, D=3
    # a+1=b, b+2=d, c+3=f, d+1=e (wrap-around to B=1)
    out, err = run_task1(["+VBCD"], input_data=b"abcd")
    if out == b"bdfe":
        print(" [PASS] Key wrap-around works, abcd => bdfe.")
    else:
        print(f" [FAIL] Expected b'bdfe', got {out}")

def test_input_file():
    with open("test_in.txt", "wb") as f:
        f.write(b"hello")
    
    # 'B' shifts by 1
    out, err = run_task1(["-itest_in.txt", "+VB"])
    if out == b"ifmmp":
        print(" [PASS] Reading from file works.")
    else:
        print(f" [FAIL] Got {out}")
    os.remove("test_in.txt")

def test_output_file():
    # 'A' shifts by 0 (identity)
    run_task1(["-otest_out.txt", "+VA"], input_data=b"secret")
    
    if os.path.exists("test_out.txt"):
        with open("test_out.txt", "rb") as f:
            data = f.read()
        if data == b"secret":
            print(" [PASS] Writing to file works.")
        else:
            print(f" [FAIL] File content mismatch: {data}")
        os.remove("test_out.txt")
    else:
        print(" [FAIL] Output file not created.")

def test_stderr_debug():
    # Task 1.A requires all args printed to stderr
    out, err = run_task1(["-abc", "+VBCD"])
    if b"-abc" in err and b"+VBCD" in err:
        print(" [PASS] Arguments printed to stderr.")
    else:
        print(" [FAIL] Stderr missing debug info.")

def rebuild(input_data=None):
    print(" Rebuilding binary")
    cmd = ['/bin/sh', '-c', 'make clean && make']
    
    process = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=False
    )
    
    if isinstance(input_data, str):
        input_data = input_data.encode('utf-8')
        
    stdout, stderr = process.communicate(input=input_data)
    return stdout, stderr, process.returncode


if __name__ == "__main__":
    rebuild()
    if not os.path.exists("./task1"):
        print("Error: 'task1' binary not found. Run 'make' first.")
    else:
        test_stderr_debug()
        test_basic_vigenere()
        test_long_key()
        test_input_file()
        test_output_file()