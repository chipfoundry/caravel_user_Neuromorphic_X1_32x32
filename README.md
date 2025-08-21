# Caravel User Neuromorphic X1 Example

This project demonstrates the straightforward integration of a commercial Neuromorphic X1 within the `user_project_wrapper` using the IPM (IP Manager) tool.

## Get Started Quickly

### Follow these steps to set up your environment and harden the Neuromorphic X1:

1. **Clone the Repository:**

```
git clone https://github.com/BMsemi/caravel_user_Neuromorphic_X1_32x32.git
```
2. **Prepare Your Environment:**

```
cd caravel_user_Neuromorphic_X1_32x32
make setup
```
3. **Install IPM:**

```
pip install cf-ipm
```
4. **Install the Neuromorphic X1 IP:**

```
ipm install Neuromorphic_X1_32x32 --include-drafts
```
5. **Harden the Neuromorphic X1 Macro:**

```
make CF_Neuromorphic_X1_32x32_wb_wrapper
```
6. **Harden the User Project Wrapper:**

```
make user_project_wrapper
```

For further information on usage, consult the dedicated [knowledgebase article](https://chipfoundry.io/knowledge-base/commercial-neuromorphic-x1). Details about the Neuromorphic X1 IP itself are available in the [Neuromorphic X1 documentation](https://chipfoundry.io/commercial-neuromorphic-x1).
