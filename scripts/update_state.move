script{
    use aptos_minting::minting_contract;
    fun update_state<coinType>(sender: &signer,new_mint_price:u64){
        minting_contract::update_state<coinType>(sender,new_mint_price);
    }
}
