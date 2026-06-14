import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

const healthResponse = { status: "PASS", plugin: "image-inbox" };

export default definePluginEntry({
  id: "image-inbox",
  name: "Image Inbox",
  description: "Experimental minimal Image Inbox HTTP route probe.",
  register(api) {
    api.registerHttpRoute({
      method: "GET",
      path: "/plugin/image-inbox/health",
      async handler() {
        return new Response(JSON.stringify(healthResponse), {
          status: 200,
          headers: {
            "content-type": "application/json; charset=utf-8",
          },
        });
      },
    });
  },
});
