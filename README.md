
# Build script
## Deploy the contract under object

```bash
aptos move create-object-and-publish-package 
--address-name aptos_minting 
--named-addresses aptos_minting=default,admin=default
--profile default
--assume-yes
```
## Upgrade the contract
```bash
aptos move upgrade-object-package 
  --object-address $CONTRACT_ADDRESS 
  --named-addresses aptos_minting=$CONTRACT_ADDRESS,admin=default
  --profile $PUBLISHER_PROFILE 
  --assume-yes --skip-fetch-latest-git-deps
```

## Run the transfer ownership script
```bash
aptos move run-script 
   --assume-yes 
   --profile $SENDER_PROFILE 
   --compiled-script-path build/aptos_minting/bytecode_scripts/transfer_ownership.mv
```
