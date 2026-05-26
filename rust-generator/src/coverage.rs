use enumset::EnumSetType;

#[derive(EnumSetType, Debug)]
pub enum CovPoint {
    RawChain,
    LoadUseHazard,
    StoreToLoadFwd,
    BranchDense,
    CacheLineSplit,
}

