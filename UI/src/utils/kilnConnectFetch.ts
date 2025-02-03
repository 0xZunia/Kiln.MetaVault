export async function fetchOnKiln(path: string) {
	return fetch(
		`https://api${import.meta.env.DEV && ".testnet"}.kiln.fi/v1${path}`,
		{
			headers: {
				Authorization: `Bearer ${import.meta.env.VITE_KILN_API_KEY}`,
			},
		},
	).then((res) => res.json());
}
