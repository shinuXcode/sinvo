export default async function handler(_req: any, res: any) {
  try {
    const upstream = await fetch(
      "https://api.github.com/repos/shinuXcode/sinvo/releases/assets/607948218",
      {
        headers: {
          Accept: "application/octet-stream",
          "User-Agent": "Sinvo-APK-Proxy"
        },
        redirect: "follow"
      }
    );
    if (!upstream.ok) {
      res.status(upstream.status).send("Sinvo APK is temporarily unavailable.");
      return;
    }
    const body = Buffer.from(await upstream.arrayBuffer());
    res.status(200);
    res.setHeader("Content-Type", "application/vnd.android.package-archive");
    res.setHeader("Content-Disposition", 'attachment; filename="Sinvo-Android.apk"');
    res.setHeader("Content-Length", String(body.length));
    res.setHeader("Cache-Control", "public, max-age=300, s-maxage=3600");
    res.send(body);
  } catch {
    res.status(502).send("Unable to fetch the Sinvo APK right now.");
  }
}
