# Caravel User Neuromorphic_X1_32x32 Example

This project demonstrates the straightforward integration of a commercial **Neuromorphic X1 (32×32 1T1R)** analog in‑memory compute macro within the `user_project_wrapper` using the IPM (IP Manager) tool.

**Repository:** https://github.com/BMsemi/caravel_user_Neuromorphic_X1_32x32

## Get Started Quickly

Follow these steps to set up your environment and harden the Neuromorphic_X1_32x32 macro.

### Clone the Repository
```bash
git clone https://github.com/BMsemi/caravel_user_Neuromorphic_X1_32x32.git
```

### Prepare Your Environment
```bash
cd caravel_user_Neuromorphic_X1_32x32
make setup
```

### Install IPM
```bash
pip install cf-ipm
```

### Install the Neuromorphic_X1_32x32 IP
```bash
# add --include-drafts if the IP is not yet public
ipm install Neuromorphic_X1_32x32 --include-drafts
```

### Harden the Neuromorphic_X1_32x32 Macro
```bash
# adjust target name if your Makefile uses a different wrapper name
make Neuromorphic_X1_32x32_wb_wrapper
```

### Harden the User Project Wrapper
```bash
make user_project_wrapper
```

For further information on usage, consult your project documentation or IPM package docs.
