struct Position {
    position_x: f32,
    position_y: f32,
    position_z: f32,
    normal_x: f32,
    normal_y: f32,
    normal_z: f32,
    tangent_x: f32,
    tangent_y: f32,
    tangent_z: f32,
    tex_coords_x: f32,
    tex_coords_y: f32,
}

struct Velocity {
    velocity_x: f32,
    velocity_y: f32,
    velocity_z: f32,
}

struct ComputeData {
    delta_time: f32,
    nb_vertices: f32,
    sphere_radius: f32,
    sphere_center_x: f32,
    sphere_center_y: f32,
    sphere_center_z: f32,
    vertex_mass: f32,
    structural_stiffness: f32,
    shear_stiffness: f32,
    bend_stiffness: f32,
    structural_damping: f32,
    shear_damping: f32,
    bend_damping: f32,
}

struct Spring {
    vertex_index_1: f32,
    vertex_index_2: f32,
    rest_length: f32,
}

@group(0) @binding(0) var<storage, read_write> verticiesPositions: array<Position>;
@group(1) @binding(0) var<storage, read_write> verticiesVelocities: array<Velocity>;
@group(2) @binding(0) var<uniform> data: ComputeData;
@group(3) @binding(0) var<storage, read> springsR: array<Spring>;

@compute @workgroup_size(128, 1, 1)
fn main(@builtin(global_invocation_id) param: vec3<u32>) {
    if (param.x >= u32(data.nb_vertices)) {
          return;
    }

    var spring = springsR[param.x];

    verticiesPositions[param.x].position_x += verticiesVelocities[param.x].velocity_x * data.delta_time;
    verticiesPositions[param.x].position_y += verticiesVelocities[param.x].velocity_y * data.delta_time;
    verticiesPositions[param.x].position_z += verticiesVelocities[param.x].velocity_z * data.delta_time;

    let sphere_center = vec3<f32>(data.sphere_center_x, data.sphere_center_y, data.sphere_center_z);
    let sphere_radius = data.sphere_radius;
    let position = vec3<f32>(verticiesPositions[param.x].position_x, verticiesPositions[param.x].position_y, verticiesPositions[param.x].position_z);

    let distance = length(position - sphere_center);
    var gravity_a = vec3<f32>(0.0, 0.0, 0.0);
    gravity_a.y += -9.81 * data.vertex_mass;

    // MAJ des vertices de vitesse 
    verticiesVelocities[param.x].velocity_x += (gravity_a.x / data.vertex_mass) * data.delta_time;
    verticiesVelocities[param.x].velocity_y += (gravity_a.y / data.vertex_mass) * data.delta_time;
    verticiesVelocities[param.x].velocity_z += (gravity_a.z / data.vertex_mass) * data.delta_time;

    // MAJ des positions des vertices 
    verticiesPositions[param.x].position_x += 0.0;

    //si la distance est plus petite que le rayon de la sphère alors cela veux dire 
    //que notre tissu est dans la sphère donc on doit MAJ les vertices de positions 
    // en faisant la normale et mettre à jour les vertices de vitesse à 0 car les particules sur la sphère ne doivent plus accélerer
    if (distance < sphere_radius) {
        let normal = normalize(position - sphere_center);

        verticiesPositions[param.x].position_x += normal.x * (sphere_radius - distance);
        verticiesPositions[param.x].position_y += normal.y * (sphere_radius - distance);
        verticiesPositions[param.x].position_z += normal.z * (sphere_radius - distance);

        verticiesVelocities[param.x].velocity_x = 0.0;
        verticiesVelocities[param.x].velocity_y = 0.0;
        verticiesVelocities[param.x].velocity_z = 0.0;
    }
}