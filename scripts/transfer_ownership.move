script {
    use aptos_framework::object;
    // replace with actual address
    fun transfer_object(sender: &signer) {
        object::transfer(
            sender,
            object::address_to_object<object::ObjectCore>(@0x23454), // object address
            @0x1234
        );
    }
}