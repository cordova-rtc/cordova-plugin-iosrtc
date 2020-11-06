import { generator as randomNumberGenerator } from 'random-number';

export const randomNumber = randomNumberGenerator({ min: 10000, max: 99999, integer: true });
