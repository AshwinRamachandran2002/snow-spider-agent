### Installation
```bash
# Recommend Python 3.10, cuda 12.4.
pip install -r requirements.txt
pip install -e ./verl
pip install -e .
pip install antlr4-python3-runtime==4.9.*
```

Modify:
```
site-packages/vllm/sampling_params.py
```