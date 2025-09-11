shader_type canvas_item;
render_mode blend_mix;

uniform float progress : hint_range(-0.3, 1.3) = -0.3;   // posición del brillo
uniform float width    : hint_range(0.0, 1.0)  = 0.40;   // ancho de la franja
uniform float angle_deg: hint_range(-90.0, 90.0) = 30.0; // ángulo de inclinación
uniform float intensity: hint_range(0.0, 2.0)   = 0.7;   // intensidad del color añadido
uniform float alpha    : hint_range(0.0, 1.0)   = 0.0;   // transparencia máxima del brillo

void fragment() {
    vec4 base = texture(TEXTURE, UV);   // textura base del botón

    // Coordenadas centradas
    vec2 uv = UV - vec2(0.5);
    float ang = radians(angle_deg);

    // Matriz de rotación
    mat2 R = mat2(vec2(cos(ang), -sin(ang)),
                  vec2(sin(ang),  cos(ang)));

    vec2 p = R * uv;

    // Banda de brillo → más ancha según width
    float band = smoothstep(width, 0.0, abs(p.x - progress));

    // Color del brillo (blanco con transparencia controlada)
    vec3 sheen_rgb = vec3(1.0) * intensity;
    float sheen_alpha = band * alpha * base.a;

    // Combinación
    COLOR = vec4(base.rgb + sheen_rgb * sheen_alpha, base.a);
}
