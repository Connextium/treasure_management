# Treasure Management

## Overview
This repository contains the Treasure Management project and supporting workflow tooling.

---

## Prerequisites

### Environment Setup
- **Node.js**: v24.7.0  
- **npm**: v8 or higher  

### Install Go
```
brew install go
```

### Install Bun
```
brew tap oven-sh/bun
brew install bun
```

### Install Foundry (forge, cast, anvil, chisel)
```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Install CRE
```
curl -fsSL https://cre.foundry.sh/install.sh | sh
export PATH="$HOME/.cre/bin:$PATH"
```

---

## Step 0 — Create the Project

```
cre init
cd treasure_management
npm install -g bun
```

### Install Workflow Dependencies
```
bun install --cwd ./my-workflow
```

---

## Generate Types from ABI (Wagmi CLI)

```
npm install -D @wagmi/cli
npx wagmi generate --outDir ./my-workflow/generated --abi ./my-workflow/generated/marketPredictorAbi.ts --target typescript
```

### Git Ignore
Add the following to `.gitignore`:
```
/generated/
```