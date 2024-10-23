use starknet::ContractAddress;

// 发行者信息
#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct Issuer {
    pub name: ByteArray,
    pub contact: ByteArray,
    pub certification: ByteArray,
}

// NFT资产类型
#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub enum AssetType {
    Cash,
    Commodity,
    Stock,
    Bond,
    Credit,
    Art,
    IntellectualProperty,
}

#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct Valuation {
    pub currency: ByteArray,
    pub amount: u256,
}

#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct Document {
    pub document_name: ByteArray,
    pub document_type: ByteArray,
    pub document_url: ByteArray,
}

#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct AssetDetails {
    pub location: ByteArray,
    pub legal_status: ByteArray,
    pub valuation: Valuation,
    pub issued_date: ByteArray,
    pub expiry_date: ByteArray,
    pub condition: ByteArray,
    pub dimensions: ByteArray,
    pub material: ByteArray,
    pub color: ByteArray,
    pub historical_significance: ByteArray,
    pub document: Document,
}

#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct Owner {
    pub name: ByteArray,
    pub contact: ByteArray,
}

#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct RoyaltyInfo {
    pub recipient: ContractAddress,
    pub percentage: u256,
}
// NFT元数据
#[derive(Drop, Serde, Clone, starknet::Store, PartialEq)]
pub struct RWAMetadata {
    pub name: ByteArray,
    pub description: ByteArray,
    pub image: ByteArray,
    pub external_url: ByteArray,
    pub asset_id: ByteArray,
    pub issuer: Issuer,
    pub asset_type: AssetType,
    pub asset_details: AssetDetails,
    pub current_owner: Owner,
    pub royalty_info: RoyaltyInfo,
    pub legal_jurisdiction: ByteArray,
    pub disclaimer: ByteArray,
}
