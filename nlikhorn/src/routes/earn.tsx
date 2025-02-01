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
			style={{ width: "80vw", height: "80vh", borderRadius: "1rem" }}
		/>
	);
};

function Earn() {
	return <KilnWidget slug="nlik" />;
}
