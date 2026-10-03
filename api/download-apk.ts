export default async function handler(_req: any, res: any) {
  try {
    const apiResponse = await fetch(
      "https://api.github.com/repos/shinuXcode/sinvo/releases/assets/607948218",
      {
        headers: {
          Accept: "application/octet-stream",
          "X-GitHub-Api-Version": "2022-11-28",
          "User-Agent": "Sinvo-APK-Proxy"
        },
        redirect: "manual"
      }
    );

    let upstream = apiResponse;

    if (apiResponse.status === 301 || apiResponse.status === 302 || apiResponse.status === 303 || apiResponse.status === 307 || apiResponse.status === 308) {
      const location = apiResponse.headers.get("location");
      if (!location) {
        res.status(502).send("Sinvo APK download target is unavailable.");
        return;
      }
      upstream = await fetch(location, {
        headers: { "User-Agent": "Sinvo-APK-Proxy" },
        redirect: "follow"
      });
    }

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
