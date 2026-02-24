/**
 * Minimal GDExtension stub functions.
 * These do nothing but satisfy Godot's requirement for a valid entry point.
 */

#ifdef _WIN32
#define STUB_EXPORT __declspec(dllexport)
#else
#define STUB_EXPORT
#endif

void stub_func(void* userdata, int level) {}

typedef struct {
    int minimum_initialization_level;
    void *userdata;
    void (*initialize)(void *userdata, int p_level);
    void (*deinitialize)(void *userdata, int p_level);
} GDExtensionInitialization;

/**
 * GDExtension Entry Point
 * Returns 1 (success) and sets dummy initialization functions.
 */
STUB_EXPORT unsigned char swift_entry_point(void *p_get_proc_address, void *p_library, GDExtensionInitialization *r_initialization) {
    if (r_initialization) {
        r_initialization->initialize = stub_func;
        r_initialization->deinitialize = stub_func;
        r_initialization->minimum_initialization_level = 0;
    }
    return 1;
}
