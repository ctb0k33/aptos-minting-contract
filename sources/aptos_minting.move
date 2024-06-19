module aptos_minting::minting_contract {
    use std::option::{Self};
    use std::signer;
    use std::string::{Self, String, utf8};
    use aptos_std::string_utils;
    use aptos_std::type_info::{TypeInfo, type_of};

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin::{Self};
    use aptos_framework::object::{Self, ObjectCore};
    use aptos_token_objects::collection;
    use aptos_token_objects::collection::Collection;
    use aptos_token_objects::token::{Self};
    use aptos_token_objects::property_map;
    use aptos_token_objects::property_map::MutatorRef;

    ////////////
    // ERRORS //
    ////////////

    const ERROR_ACCOUNT_ALREADY_MINTED: u64 = 0;
    const ERROR_WRONG_COINTYPE: u64 = 1;


    //////////
    // CONSTANT //
    //////////

    const SEED: vector<u8> = b"seed";
    const COLLECTION_NAME: vector<u8> = b"Collection Name";
    const COLLECTION_DESCRIPTION: vector<u8> = b"Collection description";
    const COLLECTION_URI: vector<u8> = b"Collection uri";

    /////////////
    // STRUCTS //
    /////////////

    struct State has key {
        singer_cap: SignerCapability,
        mintPrice: u64,
        coin: TypeInfo
    }


    struct NFT has key, store {
        base_uri: String,
    }

    ///////////////
    // FUNCTIONS //
    ///////////////

    /**
     Initialize State resource
     Create collection
     @param signer: signer
     */
    fun init_module(signer: &signer) {
        // Create resource account
        let (_resource_account, resource_account_cap) = account::create_resource_account(signer, SEED);

        // Create State instance and move to object signer

        let state = State {
            singer_cap: resource_account_cap,
            mintPrice: 10000000,
            coin: type_of<AptosCoin>()
        };

        // take the signer capability and create collection
        let resource_signer = account::create_signer_with_capability(&state.singer_cap);
        collection::create_unlimited_collection(
            &resource_signer,
            utf8(COLLECTION_DESCRIPTION),
            utf8(COLLECTION_NAME),
            option::none(),
            utf8(COLLECTION_URI),
        );

        move_to(signer, state);
    }

    /**
         Create a new NFT
         @param name: name of the new collection
         @param description: description of the new collection
         @param uri: URI of the new collection
         */
    public entry fun mint<CoinType>(
        receiver: &signer,
        description: String,
        uri: String,
    ) acquires State {
        let state = borrow_global_mut<State>(@aptos_minting);

        // Check coin type before mint
        let coinType = state.coin;
        assert!(type_of<CoinType>() == coinType, ERROR_WRONG_COINTYPE);

        // Mint new NFT

        // Generate token_name
        let resource_account_address = account::create_resource_address(&@aptos_minting, SEED);
        let collection_address = collection::create_collection_address(
            &resource_account_address,
            &utf8(COLLECTION_NAME)
        );
        let collection = object::address_to_object<Collection>(collection_address);
        let collection_count = collection::count(collection);
        let token_name = utf8(b"token name #");
        let token_id = *option::borrow(&collection_count) + 1;
        string::append(
            &mut token_name,
            string_utils::to_string(&token_id)
        );

        let resource_signer = account::create_signer_with_capability(&state.singer_cap);
        let constructor_ref = token::create_named_token(
            &resource_signer,
            utf8(COLLECTION_NAME),
            description,
            token_name,
            option::none(),
            uri,
        );

        // Ref to mutate object token properties
        let object_signer = object::generate_signer(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);


        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, signer::address_of(receiver));
        // Soul bound token ( lock transfer )
        object::disable_ungated_transfer(&transfer_ref);

        // Init properties
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        add_NFT_property(&property_mutator_ref, utf8(b"property1"), utf8(b"value1"));
        add_NFT_property(&property_mutator_ref, utf8(b"property2"), utf8(b"value2"));
        add_NFT_property(&property_mutator_ref, utf8(b"property3"), utf8(b"value3"));

        // Publish the nft token resource with refs
        let nft_token = NFT {
            base_uri: uri,
        };

        move_to(&object_signer, nft_token);

        coin::transfer<CoinType>(receiver, @admin, state.mintPrice);

    }

    inline fun add_NFT_property(property_mutator_ref: &MutatorRef, key: String, value: String) {
        property_map::add_typed(
            property_mutator_ref,
            key,
            value
        );
    }

    public fun update_state<coinType>(signer: &signer, new_mint_price: u64) acquires State {
        is_able_to_update(signer);
        let state = borrow_global_mut<State>(@aptos_minting);
        state.mintPrice = new_mint_price;
        state.coin = type_of<coinType>()
    }


    inline fun is_able_to_update(signer: &signer) {
        let module_object = object::address_to_object<ObjectCore>(@aptos_minting);
        let signer_address = signer::address_of(signer);
        assert!((object::owner(module_object) == signer_address || signer_address == @deployer), 0);
    }
}