from dataclasses import dataclass
@dataclass(frozen=True)
class Config:
    apothem: float = 14.4852813742  # lado octogonal de 12 unidades
    wall_height: float = 24.0
    roof_peak: float = 34.5
    pillar_extension: float = 12.0
    pillar_xy: float = 6.0
    seed: int = 2408
    fog_density: float = .001


