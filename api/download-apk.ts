export default async function handler(_req: any, res: any) {
  try {
    const releaseResponse = await fetch(
      "https://api.github.com/repos/shinuXcode/sinvo/releases/tags/android-latest",
      {
        headers: {
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          "User-Agent": "Sinvo-APK-Proxy"
        },
        redirect: "follow"
      }
    );

    if (!releaseResponse.ok) {
      res.status(releaseResponse.status).send("Sinvo APK is temporarily unavailable.");
      return;
    }

    const release = await releaseResponse.json();
    const asset = Array.isArray(release.assets)
      ? release.assets.find((item: any) => item?.name === "Sinvo-Android.apk" && item?.state === "uploaded")
      : null;

    if (!asset?.url) {
      res.status(404).send("Sinvo APK is temporarily unavailable.");
      return;
    }

    const apiAssetResponse = await fetch(asset.url, {
      headers: {
        Accept: "application/octet-stream",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "Sinvo-APK-Proxy"
      },
      redirect: "manual"
    });

    let upstream = apiAssetResponse;

    if ([301, 302, 303, 307, 308].includes(apiAssetResponse.status)) {
      const location = apiAssetResponse.headers.get("location");
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
    res.setHeader("Cache-Control", "no-store");
    res.send(body);
  } catch {
    res.status(502).send("Unable to fetch the Sinvo APK right now.");
  }
}
