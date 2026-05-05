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
    print("Testing Basic Vigenere (+V1)...")
    # 'a' (97) + 1 = 'b' (98)
    # 'A' (65) + 1 = 'B' (66)
    out, err = run_task1(["+V1"], input_data=b"abcABC")
    if out == b"bcdBCD":
        print(" [PASS] Basic shift works.")
    else:
        print(f" [FAIL] Expected b'bcdBCD', got {out}")

def test_long_key():
    print("Testing Long Key (+V123)...")
    # a+1=b, b+2=d, c+3=f, d+1=e ...
    out, err = run_task1(["+V123"], input_data=b"abcd")
    if out == b"bdfe":
        print(" [PASS] Key wrap-around works.")
    else:
        print(f" [FAIL] Expected b'bdfe', got {out}")

def test_input_file():
    print("Testing Input File (-i)...")
    with open("test_in.txt", "wb") as f:
        f.write(b"hello")
    
    out, err = run_task1(["-itest_in.txt", "+V1"])
    if out == b"ifmmp":
        print(" [PASS] Reading from file works.")
    else:
        print(f" [FAIL] Got {out}")
    os.remove("test_in.txt")

def test_output_file():
    print("Testing Output File (-o)...")
    run_task1(["-otest_out.txt", "+V0"], input_data=b"secret")
    
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
    print("Testing Stderr Debug Printout...")
    # Task 1.A requires all args printed to stderr
    out, err = run_task1(["-abc", "+V123"])
    if b"-abc" in err and b"+V123" in err:
        print(" [PASS] Arguments printed to stderr.")
    else:
        print(" [FAIL] Stderr missing debug info.")

if __name__ == "__main__":
    if not os.path.exists("./task1"):
        print("Error: 'task1' binary not found. Run 'make' first.")
    else:
        test_stderr_debug()
        test_basic_vigenere()
        test_long_key()
        test_input_file()
        test_output_file()