interface InstallationType {
    token: string;
    repositories?: object | null;
    expires_at: string;
    permissions?: any;
    installationId: number;
}
export declare const fetchInstallationToken: ({ appId, githubApiUrl, installationId, owner, permissions, privateKey, repo, }: Readonly<{
    appId: string;
    githubApiUrl: URL;
    installationId?: number | undefined;
    owner: string;
    permissions?: Record<string, string> | undefined;
    privateKey: string;
    repo: string;
}>) => Promise<InstallationType>;
export {};
