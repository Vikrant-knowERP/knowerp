import Planner from './planner';
import { requireAuth } from './auth';
export const dynamic = 'force-dynamic';

export default async function Home() {
  await requireAuth('/');
  return <Planner />;
}
