// Functions for random generation

// Ronjas tutorials, 2018 (https://www.ronja-tutorials.com/)
float rand1dTo1d(float3 value, float mutator = 0.546) {
	float random = frac(sin(value + mutator) * 143758.5453);
	return random;
}
float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)) {
	float2 smallValue = cos(value);
	float random = dot(smallValue, dotDir);
	random = frac(sin(random) * 143758.5453);
	return random;
}

//get a scalar random value from a 3d value
float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)) {
	//make value smaller to avoid artefacts
	float3 smallValue = sin(value);
	//get scalar value from 3d vector
	float random = dot(smallValue, dotDir);
	//make value more random by making it bigger and then taking teh factional part
	random = frac(sin(random) * 143758.5453);
	return random;
}
float3 rand3dTo3d(float3 value) {
	return float3(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
		rand3dTo1d(value, float3(73.156, 52.235, 09.151))
		);
}

// Voronoise functions
// Ronjas tutorials, 2018 https://www.ronja-tutorials.com/post/029-tiling-noise/#tileable-noise
#define OCTAVES 4
float3 voronoiNoise(float3 value, float3 period, float jitter) {
	float3 baseCell = floor(value);

	//first pass to find the closest cell
	//float minDistToCell = 10;
	float3 toClosestCell;
	float3 closestCell;
	float2 F = 1e6;
	for (int x1 = -1; x1 <= 1; x1++) {
		for (int y1 = -1; y1 <= 1; y1++) {
			for (int z1 = -1; z1 <= 1; z1++) {
				float3 cell = baseCell + float3(x1, y1, z1);
				float3 tiledCell = modulo(cell, period);
				float3 cellPosition = cell + rand3dTo3d(tiledCell) * jitter;
				float3 toCell = cellPosition - value;
				float distToCell = toCell.x * toCell.x + toCell.y * toCell.y + toCell.z * toCell.z;
				if (distToCell < F[0]) {
					F[1] = F[0];
					F[0] = distToCell;
					closestCell = cell;
					toClosestCell = toCell;
				}
				else if (distToCell < F[1]) {
					F[1] = distToCell;
				}
			}
		}
	}

	//second pass to find the distance to the closest edge
	float minEdgeDistance = 10;
	for (int x2 = -1; x2 <= 1; x2++) {
		for (int y2 = -1; y2 <= 1; y2++) {
			for (int z2 = -1; z2 <= 1; z2++) {
				float3 cell = baseCell + float3(x2, y2, z2);
				float3 tiledCell = modulo(cell, period);
				float3 cellPosition = cell + rand3dTo3d(tiledCell);
				float3 toCell = cellPosition - value;

				float3 diffToClosestCell = abs(closestCell - cell);
				bool isClosestCell = diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z < 0.01;
				if (!isClosestCell) {
					float3 toCenter = (toClosestCell + toCell);
					float3 cellDifference = normalize(toCell - toClosestCell);
					float edgeDistance = dot(toCenter, cellDifference);
					minEdgeDistance = min(minEdgeDistance, edgeDistance);
					//F[1] = minEdgeDistance;
				}
			}
		}
	}

	float random = rand3dTo1d(modulo(closestCell, period));
	return float3(saturate(F[0]), saturate(F[1]), random);
}