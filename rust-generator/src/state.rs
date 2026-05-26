use enumset::EnumSet;
use rand::{RngExt};
use rand_mt::Mt64;

use crate::coverage::CovPoint;

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum RegKind {
    #[default]
    Uninitialized = 0,
    Scalar,
    Pointer,
    Reserved,
}

pub type RegionId = u32;

pub struct MemRegion {
    pub id: RegionId ,
    pub size: u64,
    pub base_reg: u8,
    pub watermark: u64,
    pub label: String,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct RegInfo {
    kind: RegKind,
    region: Option<RegionId>,
    offset: u64,
}

pub struct GeneratorState {
    seed: u64,
    rng: Mt64,
    regions: Vec<MemRegion>,
    regs: [RegInfo; Self::NUM_GPRS as usize],
    last_written: Option<u8>,
    scratch_region_id: Option<RegionId>,
    label_counter: u32,
    coverage_hits: EnumSet<CovPoint>,
}

impl GeneratorState {
    pub const NUM_GPRS: u8 = 31;
    pub const NUM_GPRS_USIZE: usize = Self::NUM_GPRS as usize;
    pub const SCRATCH_REGISTER: u8 = 20;
    pub const SIG_POINTER: u8 = 21;
    pub const SCRATCH_POINTER: u8 = 22;

    pub fn new(seed: u64) -> Self {
        let mut state = Self {
            seed,
            rng: Mt64::new(seed),
            regions: Vec::new(),
            regs: std::array::from_fn(|_| RegInfo::default()),
            last_written: None,
            scratch_region_id: None,
            label_counter: 0,
            coverage_hits: EnumSet::empty(),
        };
        state.regs[Self::SCRATCH_REGISTER as usize].kind = RegKind::Reserved;
        state.regs[Self::SIG_POINTER as usize].kind = RegKind::Reserved;
        state.regs[Self::SCRATCH_POINTER as usize].kind = RegKind::Reserved;

        state
    }

    pub fn kind_of(&self, reg: u8) -> RegKind { self.regs[reg as usize].kind }
    pub fn info_of(&self, reg: u8) -> RegInfo { self.regs[reg as usize] }
    pub fn rng(&mut self) -> &mut Mt64 { &mut self.rng }
    pub fn seed(&self) -> u64 { self.seed }

    pub fn pick_initialized_gpr(&mut self) -> Option<u8> {
        let mut candidates = [0u8; Self::NUM_GPRS_USIZE];
        let mut count: usize = 0;
        for i in 0..Self::NUM_GPRS_USIZE {
            let k = self.regs[i].kind;
            if matches!(k, RegKind::Scalar | RegKind::Pointer) {
                candidates[count] = i as u8;
                count += 1;
            }
        }
        if count == 0 { return None };

        Some(candidates[self.rng.random_range(0..count)])
    }

    pub fn pick_writable_gpr(&mut self) -> Option<u8> {
        let mut candidates = [0u8; Self::NUM_GPRS_USIZE];
        let mut count: usize = 0;
        for i in 0..Self::NUM_GPRS_USIZE {
            let k = self.regs[i].kind;
            if k != RegKind::Reserved {
                candidates[count] = i as u8;
                count += 1;
            }
        }
        if count == 0 { return None; }


        Some(candidates[self.rng.random_range(0..count)])
    }

    pub fn pick_pointer_gpr(&mut self, min_headroom: u64) -> Option<u8> {
        let mut candidates = [0u8; Self::NUM_GPRS_USIZE];
        let mut count: usize = 0;

        for i in 0..Self::NUM_GPRS_USIZE {
            let info = self.regs[i];
            if info.kind != RegKind::Pointer { continue; }
            let Some(region_id) = info.region else { continue; };
            let mem = &self.regions[region_id as usize];
            let remaining: u64 = mem.size - info.offset;

            if remaining >= min_headroom {
                candidates[count] = i as u8;
                count += 1;
            }
        }
        if count == 0 { return None; }

        Some(candidates[self.rng.random_range(0..count)])
    }

    pub fn mark_scalar(&mut self, reg: u8) {
        self.regs[reg as usize] = RegInfo { kind: RegKind::Scalar, ..RegInfo::default() };
        self.last_written = Some(reg);
    }
    pub fn mark_pointer(&mut self, reg: u8, region: RegionId, offset: u64) { self.regs[reg as usize] = RegInfo { kind: RegKind::Pointer, region: Some(region), offset}; }
    pub fn mark_reserved(&mut self, reg: u8) { self.regs[reg as usize] = RegInfo { kind: RegKind::Reserved, ..RegInfo::default() }; }
    pub fn mark_uninitialized(&mut self, reg: u8) { self.regs[reg as usize] = RegInfo { kind: RegKind::Uninitialized, ..RegInfo::default() }; }


    pub fn next_label_id(&mut self) -> u32 {
        let id = self.label_counter;
        self.label_counter += 1;
        id
    }

    pub fn get_region(&self, id: RegionId) -> &MemRegion { &self.regions[id as usize] }
    pub fn add_region(&mut self, size: u64, base_reg: u8, label: String) -> RegionId {
        let id: RegionId = self.regions.len() as RegionId;
        self.regions.push( MemRegion { 
            id,
            size,
            base_reg,
            watermark: 0,
            label
        });

        id
    }
    pub fn advance_watermark(&mut self, id: RegionId, bytes: u64) { self.regions[id as usize].watermark += bytes; }

    pub fn get_scratch_region_id(&self) -> Option<RegionId> { self.scratch_region_id }
    pub fn set_scratch_region_id(&mut self, id: RegionId) { self.scratch_region_id = Some(id); }

    pub fn get_last_written_reg(&self,) -> Option<u8> { self.last_written }

    pub fn hit_coverage(&mut self, p: CovPoint) { self.coverage_hits.insert(p); }
    pub fn get_coverage_hits(&self) -> EnumSet<CovPoint> { self.coverage_hits }
}
