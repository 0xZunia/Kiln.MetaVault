import { useGetCurrentMetaVault } from "@/hooks/metaVault";
import { metaVaultABI } from "@/utils/metaVaultABI";
import { Button } from "@chakra-ui/react";
import { useEffect, useState } from "react";
import { useWaitForTransactionReceipt, useWriteContract } from "wagmi";

export function DepositButton({
	token_address,
	amount,
}: {
	token_address: `0x${string}`;
	amount: bigint;
}) {
	// State management
	const { vaultAddress } = useGetCurrentMetaVault();
	const [step, setStep] = useState("approve");

	// 1. Approve transaction
	const { data: approveHash, writeContract: approveToken } = useWriteContract();
	const { isLoading: approving, isSuccess: approved } =
		useWaitForTransactionReceipt({
			hash: approveHash,
		});

	// 2. Deposit transaction
	const { data: depositHash, writeContract: depositToken } = useWriteContract();
	const { isLoading: depositing, isSuccess: deposited } =
		useWaitForTransactionReceipt({
			hash: depositHash,
		});

	// Handlers
	const handleApprove = () => {
		approveToken({
			abi: [
				{
					name: "approve",
					type: "function",
					stateMutability: "nonpayable",
					inputs: [
						{ name: "spender", type: "address" },
						{ name: "amount", type: "uint256" },
					],
					outputs: [{ name: "success", type: "bool" }],
				},
			],
			address: token_address,
			functionName: "approve",
			args: [vaultAddress as `0x${string}`, amount],
		});
	};
	const handleDeposit = () => {
		depositToken({
			abi: metaVaultABI,
			address: vaultAddress as `0x${string}`,
			functionName: "deposit",
			args: [token_address, amount],
		});
	};

	// Effects
	useEffect(() => {
		if (approved) {
			setStep("deposit");
		}
	}, [approved]);

	return (
		<>
			{/* Step 1: approve */}
			{step === "approve" && (
				<Button
					onClick={handleApprove}
					loading={approving}
					disabled={approving || approved}
				>
					Approve
				</Button>
			)}

			{/* Step 2: deposit */}
			{step === "deposit" && (
				<Button
					onClick={handleDeposit}
					loading={depositing}
					disabled={depositing || deposited}
				>
					Deposit
				</Button>
			)}
		</>
	);
}
