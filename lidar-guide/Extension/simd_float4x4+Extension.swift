//
//  simd_float4x4+Extension.swift
//  lidar-guide
//
//  Created by Bruno de Borba on 27/09/21.
//

import ARKit

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
