import { getOctokit } from "@actions/github";
import { createAppAuth } from "@octokit/auth-app";
import { request } from "@octokit/request";

interface InstallationType {
    token: string,
    repositories?: object | null,
    expires_at: string;
    permissions?: any,
    installationId: number
}

export const fetchInstallationToken = async ({
    appId,
    githubApiUrl,
    installationId,
    owner,
    permissions,
    privateKey,
    repo,
}: Readonly<{
    appId: string;
    githubApiUrl: URL;
    installationId?: number;
    owner: string;
    permissions?: Record<string, string>;
    privateKey: string;
    repo: string;
}>): Promise<InstallationType> => {
    const app = createAppAuth({
        appId,
        privateKey,
        request: request.defaults({
            baseUrl: githubApiUrl
                .toString()
                // Remove optional trailing `/`.
                .replace(/\/$/, ""),
        }),
    });

    const authApp = await app({ type: "app" });
    const octokit = getOctokit(authApp.token);

    if (installationId === undefined) {
        try {
            ({
                data: { id: installationId },
            } = await octokit.rest.apps.getRepoInstallation({ owner, repo }));
        } catch (error: unknown) {
            throw new Error(
                "Could not get repo installation. Is the app installed on this repo?",
                { cause: error },
            );
        }
    }

    try {
        const { data: installation } =
            await octokit.rest.apps.createInstallationAccessToken({
                installation_id: installationId,
                permissions,
            });
        const result:InstallationType = {
            token: installation.token,
            expires_at: installation.expires_at,
            permissions: installation.permissions,
            repositories: installation.repositories,
            installationId: installationId
        }
        return result;
    } catch (error: unknown) {
        throw new Error("Could not create installation access token.", {
            cause: error,
        });
    }
};