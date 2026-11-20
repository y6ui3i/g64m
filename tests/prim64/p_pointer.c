// Pointers: a linked list walked, a buffer read and written through moving pointers, and
// a pointer to a pointer.
// flags: int
#include "prim.h"
struct node { struct node *next; u64 v; };
static struct node nodes[4096];
static u64 a[4096], b[4096];
NOINLINE static u64 walk(const struct node *p) {
    u64 s = 0;
    while (p) { s += p->v; p = p->next; }
    return s;
}
NOINLINE static void copy(u64 *d, const u64 *s, const u64 *end) {
    while (s != end) *d++ = *s++ + 1;
}
NOINLINE static u64 unlink_odd(struct node **pp) {
    u64 n = 0;
    while (*pp) {
        if ((*pp)->v & 1) { *pp = (*pp)->next; n++; } else pp = &(*pp)->next;
    }
    return n;
}
int main(void) {
    // The list goes through the nodes in an order that is not the array's.
    struct node *head = 0;
    for (int i = 0; i < 4096; i++) {
        struct node *n = &nodes[i * 1237 & 4095];
        n->v = next();
        n->next = head;
        head = n;
    }
    for (int i = 0; i < 4096; i++) a[i] = next();
    u64 s = 0;
    for (int k = 0; k < 500; k++) {
        s += walk(head);
        copy(b, a, a + 4096);
        copy(a, b, b + 4096);
    }
    put("walk", s);
    put("copy", a[77]);
    put("unlink", unlink_odd(&head));
    put("left", walk(head));
    return 0;
}
