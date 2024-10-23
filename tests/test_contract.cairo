use core::serde::Serde;
use core::result::ResultTrait;
// use core::num::traits::Zero;
// use core::integer::BoundedInt;
use core::num::traits::Bounded;
use starknet::{
    ContractAddress,
    contract_address_const, // get_caller_address, get_block_number, get_contract_address
};
use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;

use snforge_std::{
    declare, ContractClass, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, start_cheat_chain_id_global, stop_cheat_chain_id_global,
};

use nftwrapper::NFTWrapper::INFTWrapperSafeDispatcher;
use nftwrapper::NFTWrapper::INFTWrapperSafeDispatcherTrait;
use nftwrapper::NFTWrapper::INFTWrapperDispatcher;
use nftwrapper::NFTWrapper::INFTWrapperDispatcherTrait;
use nftwrapper::RWANFT::IRWANFTDispatcher;
use nftwrapper::RWANFT::IRWANFTDispatcherTrait;
use nftwrapper::RWANFT::IRWANFTSafeDispatcher;
use nftwrapper::RWANFT::IRWANFTSafeDispatcherTrait;
use nftwrapper::rwaMetadata::{RWAMetadata, AssetDetails, Valuation, Document, Owner, RoyaltyInfo, Issuer, AssetType};
use nftwrapper::NFTWrappedToken::INFTWrappedTokenDispatcher;
use nftwrapper::NFTWrappedToken::INFTWrappedTokenDispatcherTrait;
use nftwrapper::NFTWrappedToken::INFTWrappedTokenSafeDispatcher;
use nftwrapper::NFTWrappedToken::INFTWrappedTokenSafeDispatcherTrait;
use nftwrapper::dex::IDexDispatcher;
use nftwrapper::dex::IDexDispatcherTrait;

const SIGNER: felt252 = 0x063C81D15Dd342E8F22a874EE55a59865B04012E5b44098D3f7a8e0F0e0a7640;
const MESSAGE_HASH: felt252 = 0x59d66bd11d04182618899a03df2d8514ed0b0206bf79bca05ca646d61a29ec2;
const SIG_R: felt252 = 3002743939580725769167321527863868739260876211371703816520939609580323232443;
const SIG_S: felt252 = 1528852716039291691879751464522935111213976863453577796642524995190297805543;

const MESSAGE_HASH2: felt252 = 0x26bd59c444e076ff825605e514d23bd8bc1ccf7b522ec81464abf9c86ea848c;
const SIG_R2: felt252 = 1216475488420569236093423925754117753968156289231205597838789217073337923983;
const SIG_S2: felt252 = 2531399590006589553517515162600122319417033888525242050355364589968259150768;

const PUBLIC_KEY: felt252 = 0x3b1da8fc90ccc7a3e1fa0e37d944e89ed0a7cc4f835b92fd66d1b961f8a281c;

fn test_metadata() -> RWAMetadata {
    RWAMetadata {
        name: "test",
        description: "test",
        image: "test",
        external_url: "test",
        asset_id: "test",
        issuer: Issuer {
            name: "test",
            contact: "test",
            certification: "test",
        },
        asset_type: AssetType::Commodity,
        asset_details: AssetDetails {
            location: "test",
            legal_status: "test",
            valuation: Valuation {
                currency: "test",
                amount: 0,
            },
            issued_date: "test",
            expiry_date: "test",
            condition: "test",
            dimensions: "test",
            material: "test",
            color: "test",
            historical_significance: "test",
            document: Document {
                document_name: "test",
                document_type: "test",
                document_url: "test",
            },
        },
        current_owner: Owner {
            name: "test",
            contact: "test",
        },
        royalty_info: RoyaltyInfo {
            recipient: contract_address_const::<'1'>(),
            percentage: 0,
        },
        legal_jurisdiction: "test",
        disclaimer: "test",
    }
}

fn deploy_account(address: ContractAddress) {
    let contract = declare("Account").unwrap().contract_class();
    let args = array![PUBLIC_KEY];
    let _address = contract.deploy_at(@args, address);
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn deploy_rwa_contract(default_admin: ContractAddress, minter: ContractAddress) -> ContractAddress {
    let contract = declare("RWANFT").unwrap().contract_class();
    let args: Array<felt252> = array![
        default_admin.into(), minter.into(),
    ];
    let (contract_address, _) = contract.deploy(@args).unwrap();
    contract_address
}

fn deploy_wrapper_contract(default_admin: ContractAddress) -> (ContractClass, ContractAddress) {
    let contract = declare("NFTWrapper").unwrap().contract_class();
    let wrapped_token = declare("NFTWrappedToken").unwrap().contract_class();
    let args: Array<felt252> = array![
        default_admin.into(), (*wrapped_token.class_hash).into(), SIGNER.into(),
    ];
    let (contract_address, _) = contract.deploy(@args).unwrap();
    (*wrapped_token, contract_address)
}

#[test]
fn test_get_default_admin() {
    let (_, contract_address) = deploy_wrapper_contract(contract_address_const::<1>());

    let dispatcher = INFTWrapperDispatcher { contract_address };
    let has_role = dispatcher.has_role(DEFAULT_ADMIN_ROLE, contract_address_const::<1>());
    assert(has_role == true, 'No admin role');
    let dont_have_role = dispatcher.has_role(DEFAULT_ADMIN_ROLE, contract_address_const::<2>());
    assert(dont_have_role == false, 'Should not have admin role');
}

#[test]
fn test_create_wrapped_token() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (token_contract, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_dispatcher = INFTWrapperDispatcher { contract_address: wrapper_contract_address };

    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);

    wrapper_dispatcher.create_wrapped_token(nft_contract_address, token_contract.class_hash, 1);
    let conversion_rate = wrapper_dispatcher.get_conversion_rate(nft_contract_address);
    assert(conversion_rate == 1, 'Conversion rate should be 1');
}

#[test]
fn test_wrap_nft() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (token_contract, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_dispatcher = INFTWrapperDispatcher { contract_address: wrapper_contract_address };

    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);
    let nft_contract_dispatcher = IRWANFTDispatcher { contract_address: nft_contract_address };

    // create wrapped token
    let wrapped_token_ca = wrapper_dispatcher
        .create_wrapped_token(nft_contract_address, token_contract.class_hash, 1);
    let wrapped_token_dispatcher = INFTWrappedTokenDispatcher {
        contract_address: wrapped_token_ca
    };
    assert(wrapped_token_dispatcher.name() == nft_contract_dispatcher.name(), 'name not set');
    assert(wrapped_token_dispatcher.symbol() == nft_contract_dispatcher.symbol(), 'symbol not set');

    let caller_address: ContractAddress = contract_address_const::<'minter'>();
    deploy_account(caller_address);

    start_cheat_caller_address(nft_contract_address, caller_address);
    // mint a test NFT
    let token_id: u256 = 1;
    nft_contract_dispatcher.mint(test_metadata());
    nft_contract_dispatcher.mint(test_metadata());
    assert(nft_contract_dispatcher.owner_of(token_id) == caller_address, 'NFT not minted');

    // approve the NFT
    nft_contract_dispatcher.set_approval_for_all(wrapper_contract_address, true);
    stop_cheat_caller_address(nft_contract_address);
    // wrap the NFT
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher.wrap(nft_contract_address, token_id);
    stop_cheat_caller_address(wrapper_contract_address);
    assert(
        nft_contract_dispatcher.owner_of(token_id) == wrapper_contract_address, 'NFT not wrapped'
    );
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 1, 'Wrapped token not minted');
    // let nft_pool = wrapper_dispatcher.get_nft_pool(nft_contract_address);
// assert(nft_pool.len() == 1, 'NFT not added to pool');
}

#[test]
fn test_unwrap_nft() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (token_contract, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_dispatcher = INFTWrapperDispatcher { contract_address: wrapper_contract_address };

    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);
    println!("nft contract address: {:?}", nft_contract_address);
    let nft_contract_dispatcher = IRWANFTDispatcher { contract_address: nft_contract_address };

    // create wrapped token
    let wrapped_token_ca = wrapper_dispatcher
        .create_wrapped_token(nft_contract_address, token_contract.class_hash, 1);
    let wrapped_token_dispatcher = INFTWrappedTokenDispatcher {
        contract_address: wrapped_token_ca
    };
    assert(wrapped_token_dispatcher.name() == nft_contract_dispatcher.name(), 'name not set');
    assert(wrapped_token_dispatcher.symbol() == nft_contract_dispatcher.symbol(), 'symbol not set');

    let caller_address: ContractAddress = contract_address_const::<'minter'>();
    deploy_account(caller_address);
    deploy_account(contract_address_const::<SIGNER>());

    start_cheat_caller_address(nft_contract_address, caller_address);
    // mint a test NFT
    let token_id: u256 = 1;
    nft_contract_dispatcher.mint(test_metadata());
    nft_contract_dispatcher.mint(test_metadata());
    assert(nft_contract_dispatcher.owner_of(token_id) == caller_address, 'NFT not minted');

    // approve the NFT
    nft_contract_dispatcher.set_approval_for_all(wrapper_contract_address, true);
    stop_cheat_caller_address(nft_contract_address);
    // wrap the NFT
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher.wrap(nft_contract_address, token_id);
    stop_cheat_caller_address(wrapper_contract_address);
    assert(
        nft_contract_dispatcher.owner_of(token_id) == wrapper_contract_address, 'NFT not wrapped'
    );
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 1, 'Wrapped token not minted');

    start_cheat_chain_id_global('SN_SEPOLIA');
    // approve the wrapped token
    start_cheat_caller_address(wrapped_token_ca, caller_address);
    wrapped_token_dispatcher.approve(wrapper_contract_address, Bounded::MAX);
    stop_cheat_caller_address(wrapped_token_ca);
    // unwrap the NFT
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher.unwrap(nft_contract_address, token_id, array![SIG_R.into(), SIG_S.into()]);
    stop_cheat_caller_address(wrapper_contract_address);
    assert(nft_contract_dispatcher.owner_of(token_id) == caller_address, 'NFT not unwrapped');
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 0, 'Wrapped token not burned');
    // assert(
    //     wrapper_dispatcher.get_nft_pool(nft_contract_address).len() == 0,
    //     'NFT not removed from pool'
    // );

    // mint three NFTs
    start_cheat_caller_address(nft_contract_address, caller_address);
    let token_id1: u256 = 2;
    nft_contract_dispatcher.mint(test_metadata());
    let token_id2: u256 = 3;
    nft_contract_dispatcher.mint(test_metadata());
    let token_id3: u256 = 4;
    nft_contract_dispatcher.mint(test_metadata());
    stop_cheat_caller_address(nft_contract_address);
    // wrap the NFTs
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher.wrap(nft_contract_address, token_id1);
    wrapper_dispatcher.wrap(nft_contract_address, token_id2);
    wrapper_dispatcher.wrap(nft_contract_address, token_id3);
    stop_cheat_caller_address(wrapper_contract_address);
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 3, 'Wrapped tokens not minted');
    // remove the first NFT from the pool
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher
        .unwrap(nft_contract_address, token_id2, array![SIG_R2.into(), SIG_S2.into()]);
    stop_cheat_caller_address(wrapper_contract_address);
    // println!("nft pool: {:?}", wrapper_dispatcher.get_nft_pool(nft_contract_address));
    // assert(
    //     wrapper_dispatcher.get_nft_pool(nft_contract_address).len() == 2,
    //     'NFT not removed from pool'
    // );
    stop_cheat_chain_id_global();
}

#[test]
#[feature("safe_dispatcher")]
fn test_mint_wrapped_token_without_permission() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (token_contract, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_dispatcher = INFTWrapperDispatcher { contract_address: wrapper_contract_address };

    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);

    // create wrapped token
    let wrapped_token_ca = wrapper_dispatcher
        .create_wrapped_token(nft_contract_address, token_contract.class_hash, 1);
    let wrapped_token_safe_dispatcher = INFTWrappedTokenSafeDispatcher {
        contract_address: wrapped_token_ca
    };

    // test mint without permission
    let caller_address: ContractAddress = contract_address_const::<'minter'>();
    deploy_account(caller_address);
    start_cheat_caller_address(wrapped_token_ca, caller_address);
    match wrapped_token_safe_dispatcher.mint(caller_address, 1) {
        Result::Ok(_) => panic!("Minting wrapped token should fail without permission"),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is missing role', *panic_data.at(0));
        }
    }
    stop_cheat_caller_address(wrapped_token_ca);
}

#[test]
#[feature("safe_dispatcher")]
fn test_create_unauthorized_wrapped_token() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (_, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_safe_dispatcher = INFTWrapperSafeDispatcher {
        contract_address: wrapper_contract_address
    };
    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);
    match wrapper_safe_dispatcher
        .create_wrapped_token(
            nft_contract_address, *declare("MaliciousToken").unwrap().contract_class().class_hash, 1
        ) {
        Result::Ok(_) => panic!("Creating wrapped token should fail without permission"),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'invalid classhash', *panic_data.at(0));
        }
    }
}

#[test]
fn test_dex_pool() {
    let default_admin = contract_address_const::<'default_admin'>();
    let (token_contract, wrapper_contract_address) = deploy_wrapper_contract(default_admin);
    let wrapper_dispatcher = INFTWrapperDispatcher { contract_address: wrapper_contract_address };

    let minter = contract_address_const::<'minter'>();
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);
    let nft_contract_dispatcher = IRWANFTDispatcher { contract_address: nft_contract_address };

    // create wrapped token
    let wrapped_token_ca = wrapper_dispatcher
        .create_wrapped_token(nft_contract_address, token_contract.class_hash, 1000);
    let wrapped_token_dispatcher = INFTWrappedTokenDispatcher {
        contract_address: wrapped_token_ca
    };
    assert(wrapped_token_dispatcher.name() == nft_contract_dispatcher.name(), 'name not set');
    assert(wrapped_token_dispatcher.symbol() == nft_contract_dispatcher.symbol(), 'symbol not set');

    let caller_address: ContractAddress = contract_address_const::<'minter'>();
    deploy_account(caller_address);

    start_cheat_caller_address(nft_contract_address, caller_address);
    // mint a test NFT
    let token_id: u256 = 1;
    nft_contract_dispatcher.mint(test_metadata());
    nft_contract_dispatcher.mint(test_metadata());
    assert(nft_contract_dispatcher.owner_of(token_id) == caller_address, 'NFT not minted');

    // approve the NFT
    nft_contract_dispatcher.set_approval_for_all(wrapper_contract_address, true);
    stop_cheat_caller_address(nft_contract_address);
    // wrap the NFT
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    wrapper_dispatcher.wrap(nft_contract_address, token_id);
    stop_cheat_caller_address(wrapper_contract_address);
    assert(
        nft_contract_dispatcher.owner_of(token_id) == wrapper_contract_address, 'NFT not wrapped'
    );
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 1000, 'Wrapped token not minted');

    // deploy ether token
    let ether_ca = contract_address_const::<
        0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    >();
    let mut args: Array<felt252> = array![default_admin.into(), caller_address.into(),];
    let name: ByteArray = "Ethereum";
    let symbol: ByteArray = "ETH";
    name.serialize(ref args);
    symbol.serialize(ref args);
    let _ = token_contract.deploy_at(@args, ether_ca);
    let ether_dispatcher = INFTWrappedTokenDispatcher { contract_address: ether_ca };
    // mint eth to caller
    start_cheat_caller_address(ether_ca, caller_address);
    ether_dispatcher.mint(caller_address, 1000);
    // println!("eth balance: {:?}", ether_dispatcher.balance_of(caller_address));
    stop_cheat_caller_address(ether_ca);

    // test dex function
    start_cheat_caller_address(wrapper_contract_address, caller_address);
    let dex_class = *declare("Dex").unwrap().contract_class();
    let dex_pool_ca = wrapper_dispatcher
        .create_dex_pool(nft_contract_address, dex_class.class_hash, 10);
    // println!("dex pool: {:?}", dex_pool_ca);
    stop_cheat_caller_address(wrapper_contract_address);
    let dex_dispatcher = IDexDispatcher { contract_address: dex_pool_ca };
    // approve token to dex pool
    start_cheat_caller_address(wrapped_token_ca, caller_address);
    wrapped_token_dispatcher.approve(dex_pool_ca, 1000);
    stop_cheat_caller_address(wrapped_token_ca);
    start_cheat_caller_address(ether_ca, caller_address);
    ether_dispatcher.approve(dex_pool_ca, 1000);
    stop_cheat_caller_address(ether_ca);
    // test add liquidity
    start_cheat_caller_address(dex_pool_ca, caller_address);
    let share = dex_dispatcher.add_liquidity(100, 100);
    // println!("share: {:?}", share);
    assert(share == 100, 'Liquidity not added');
    stop_cheat_caller_address(dex_pool_ca);
    assert(wrapped_token_dispatcher.balance_of(dex_pool_ca) == 100, 'Liquidity not added');
    assert(ether_dispatcher.balance_of(dex_pool_ca) == 100, 'Liquidity not added');
    // test swap
    start_cheat_caller_address(dex_pool_ca, caller_address);
    dex_dispatcher.swap(ether_ca, 10);
    // println!("token balance: {:?}", wrapped_token_dispatcher.balance_of(caller_address));
    // println!("eth balance: {:?}", ether_dispatcher.balance_of(caller_address));
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 908, 'Token not swapped');
    assert(ether_dispatcher.balance_of(caller_address) == 890, 'Token not swapped');
    // // test remove liquidity
    dex_dispatcher.remove_liquidity(10_u256);
    // println!("token balance: {:?}", wrapped_token_dispatcher.balance_of(caller_address));
    // println!("eth balance: {:?}", ether_dispatcher.balance_of(caller_address));
    assert(wrapped_token_dispatcher.balance_of(caller_address) == 917, 'Liquidity not removed');
    assert(ether_dispatcher.balance_of(caller_address) == 901, 'Liquidity not removed');
    stop_cheat_caller_address(dex_pool_ca);
}

#[test]
#[feature("safe_dispatcher")]
fn test_rwa_function() {
    let default_admin = contract_address_const::<'default_admin'>();
    let minter = contract_address_const::<'minter'>();
    deploy_account(minter);
    deploy_account(default_admin);
    let nft_contract_address = deploy_rwa_contract(default_admin, minter);
    let nft_contract_dispatcher = IRWANFTDispatcher { contract_address: nft_contract_address };
    let nft_contract_safe_dispatcher = IRWANFTSafeDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, minter);
    nft_contract_dispatcher.mint(test_metadata());
    stop_cheat_caller_address(nft_contract_address);
    assert(nft_contract_dispatcher.owner_of(0) == minter, 'NFT not minted');
    assert(nft_contract_dispatcher.get_uri(0) == test_metadata(), 'Metadata not set');
    let new_metadata = RWAMetadata {
        name: "bjtu",
        description: "bjtu",
        image: "bjtu",
        external_url: "bjtu",
        asset_id: "bjtu",
        issuer: Issuer {
            name: "bjtu",
            contact: "bjtu",
            certification: "bjtu",
        },
        asset_type: AssetType::Cash,
        asset_details: AssetDetails {
            location: "bjtu",
            legal_status: "bjtu",
            valuation: Valuation {
                currency: "bjtu",
                amount: 0,
            },
            issued_date: "bjtu",
            expiry_date: "bjtu",
            condition: "bjtu",
            dimensions: "bjtu",
            material: "bjtu",
            color: "bjtu",
            historical_significance: "bjtu",
            document: Document {
                document_name: "bjtu",
                document_type: "bjtu",
                document_url: "bjtu",
            },
        },
        current_owner: Owner {
            name: "bjtu",
            contact: "bjtu",
        },
        royalty_info: RoyaltyInfo {
            recipient: contract_address_const::<'1'>(),
            percentage: 0,
        },
        legal_jurisdiction: "bjtu",
        disclaimer: "bjtu",
    };
    match nft_contract_safe_dispatcher.change_uri(0, new_metadata.clone()) {
        Result::Ok(_) => panic!("set metadata should fail without permission"),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Caller is missing role', *panic_data.at(0));
        }
    }
    start_cheat_caller_address(nft_contract_address, default_admin);
    nft_contract_dispatcher.change_uri(0, new_metadata.clone());
    stop_cheat_caller_address(nft_contract_address);
    assert(nft_contract_dispatcher.get_uri(0) == new_metadata, 'Metadata not set');
}
