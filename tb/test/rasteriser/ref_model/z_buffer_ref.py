class SoftwareZBuffer:
    def __init__(self, x_res, y_res, z_size):
        self.x_res = x_res
        self.y_res = y_res
        self.z_size = z_size
        self.buffer = np.full((x_res, y_res), (1 << z_size) - 1, dtype=np.uint32)

    def test_depth(self, x, y, z, func):
        current_z = self.buffer[x, y]
        if func == 0b000:  # GL_NEVER
            return False
        elif func == 0b001:  # GL_LESS
            return z < current_z
        elif func == 0b010:  # GL_LEQUAL
            return z <= current_z
        elif func == 0b011:  # GL_GREATER
            return z > current_z
        elif func == 0b100:  # GL_GEQUAL
            return z >= current_z
        elif func == 0b101:  # GL_EQUAL
            return z == current_z
        elif func == 0b110:  # GL_NOTEQUAL
            return z != current_z
        elif func == 0b111:  # GL_ALWAYS
            return True
        else:
            return z < current_z  # Default to GL_LESS

    def update(self, x, y, z):
        self.buffer[x, y] = z

    def flush(self):
        self.buffer.fill((1 << self.z_size) - 1)