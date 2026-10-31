// CRT look for Ghostty: scanlines and glow. Turned on per machine by `hax0r shader on`.
// Both move text relative to the theme's background rather than brightening or darkening the whole
// screen, so a light theme keeps its white page: its text gets a dark halo instead of a bright one.
const float SCANLINES = 0.50; // how far the dark lines pull text toward the background, 0 to 1
const float GLOW = 0.65; // how much blurred text is added back, 0 to 1
const float SCANLINE_PERIOD = 4.0; // device pixels from one dark line to the next
const float GLOW_RADIUS = 7.0; // device pixels
const int GLOW_SAMPLES = 16;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pixel = 1.0 / iResolution.xy;
    vec4 screen = texture(iChannel0, fragCoord * pixel);
    vec3 color = screen.rgb;

    // Glow: average nearby pixels on a spiral, then add how far that average is from the background.
    vec3 blur = vec3(0.0);
    for (int i = 0; i < GLOW_SAMPLES; i++) {
        float n = float(i) + 0.5;
        float radius = GLOW_RADIUS * sqrt(n / float(GLOW_SAMPLES));
        float angle = n * 2.39996;
        blur += texture(iChannel0, (fragCoord + radius * vec2(cos(angle), sin(angle))) * pixel).rgb;
    }
    color += GLOW * (blur / float(GLOW_SAMPLES) - iBackgroundColor);

    float line = 0.5 + 0.5 * cos(6.28318 * fragCoord.y / SCANLINE_PERIOD);
    color = mix(color, iBackgroundColor, SCANLINES * line);

    fragColor = vec4(color, screen.a);
}
