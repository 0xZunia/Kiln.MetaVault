import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/earn")({
	component: Earn,
});

const KilnWidget = ({ slug }: { slug: string }) => {
	return (
		<iframe
			src={`https://${slug}.widget${import.meta.env.DEV && ".testnet"}.kiln.fi`}
			title="Nlik Widget"
			allow="clipboard-write"
			style={{ width: "100%", height: "100%", borderRadius: "1rem" }}
		/>
	);
};

function Earn() {
	return <KilnWidget slug="nlik" />;
}
