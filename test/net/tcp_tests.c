#include "net/tcp.h"
#include "tobytes.h"
#include "net/sbuff.h"
#include "net/arp.h"

#include "../tinytest.h"

#include <stdio.h>

static uint8_t * g_data = 0;
uint16_t g_len;
static void capture(struct netdevice *dev, const void *ptr, uint16_t len) {
    g_data = malloc(len);
    memcpy(g_data, ptr, len);
    g_len = len;
}

void connection_refused() {
    uint8_t* syn = tobytes("92061fa31cf94a9700000000a0026db075c40000020406180402080a02ebc4ad0000000001030307");
    struct netdevice dev;
    dev.ip = 0xC0A80302;
    dev.send = capture;

    dev.send = capture;
    mac remote = {1,2,3,4,5,6};
    arp_store(remote, 0xc0a8301);
    tcp_segment(&dev, syn, 0xc0a80301);

    ASSERT_EQUALS(54, g_len);
    ASSERT_EQUALS(0x0203a8c0, *(uint32_t*)(g_data+26));
    ASSERT_EQUALS(0x0103a8c0, *(uint32_t*)(g_data+30));
    ASSERT_EQUALS(0x14, g_data[47]); // ack,rst
}

