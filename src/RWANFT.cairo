// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.18.0

use starknet::ContractAddress;
use super::rwaMetadata::{RWAMetadata};
const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");

#[starknet::interface]
pub trait IRWANFT<TContractState> {
    // fn safe_mint(
    //     ref self: TContractState, recipient: ContractAddress, token_id: u256, data: Span<felt252>
    // );
    fn mint(ref self: TContractState, metadata: RWAMetadata);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn totalSupply(self: @TContractState) -> u256;
    fn get_uri(self: @TContractState, token_id: u256) -> RWAMetadata;
    fn change_uri(ref self: TContractState, token_id: u256, metadata: RWAMetadata);
}

#[starknet::contract]
mod RWANFT {
    use AccessControlComponent::InternalTrait;
use core::num::traits::Zero;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::ERC721HooksEmptyImpl;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map
    };
    use super::{MINTER_ROLE, RWAMetadata};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlCamelImpl =
        AccessControlComponent::AccessControlCamelImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        uri: Map<u256, RWAMetadata>,
        token_id: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, default_admin: ContractAddress, minter: ContractAddress
    ) {
        self.erc721.initializer("Real Word Assets", "RWA", "");
        self.accesscontrol.initializer();

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(MINTER_ROLE, minter);
        self.accesscontrol._grant_role(MINTER_ROLE, default_admin);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn burn(ref self: ContractState, token_id: u256) {
            self.erc721.update(Zero::zero(), token_id, get_caller_address());
        }

        // #[external(v0)]
        fn safe_mint(
            ref self: ContractState,
            recipient: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {
            self.accesscontrol.assert_only_role(MINTER_ROLE);
            self.erc721.safe_mint(recipient, token_id, data);
        }

        // #[external(v0)]
        fn safeMint(
            ref self: ContractState, recipient: ContractAddress, tokenId: u256, data: Span<felt252>,
        ) {
            self.safe_mint(recipient, tokenId, data);
        }

        #[external(v0)]
        fn mint(ref self: ContractState, metadata: RWAMetadata) {
            self.accesscontrol.assert_only_role(MINTER_ROLE);
            let empty_data = ArrayTrait::<felt252>::new().span();
            let token_id_now = self.token_id.read();
            self.safe_mint(get_caller_address(), token_id_now, empty_data);
            self.uri.entry(token_id_now).write(metadata);
            self.token_id.write(token_id_now + 1);
        }

        #[external(v0)]
        fn totalSupply(self: @ContractState) -> u256 {
            self.token_id.read()
        }

        #[external(v0)]
        fn get_uri(self: @ContractState, token_id: u256) -> RWAMetadata {
            self.uri.entry(token_id).read()
        }

        #[external(v0)]
        fn change_uri(ref self: ContractState, token_id: u256, metadata: RWAMetadata) {
            self.accesscontrol.assert_only_role(DEFAULT_ADMIN_ROLE);
            self.uri.entry(token_id).write(metadata);
        }
    }
}
