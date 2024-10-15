#! https://stackoverflow.com/a/246128
SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
ROOT_DIR=$(realpath $SCRIPT_DIR/..)

cd $ROOT_DIR
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port $PORT --log-level warning
