# Consumption-Saving Problem with Endogenous Labor Supply (Hugget Economy, not AIYAGARI)

### 1 Model Description

Individuals solve

$$
\max_{\{c_t, \ell_t\}_{t \ge 0}} \mathbb{E}_0 \int_0^\infty u(c_t, \ell_t) dt \quad \text{s.t.}
$$

$$
\dot{a}_t = w z_t \ell_t + r a_t - c_t,
$$

$$
a_t \ge \underline{a},
$$

and where z`<sup>`t`</sup>` ∈ {z1, z2} follows a two-state Poisson process with intensities λ`<sup>`1`</sup>` and λ2. That is, the problem is identical to the baseline problem in Achdou, Han, Lasry, Lions, and Moll (2017) except that individuals now endogenously choose labor supply `. For concreteness we assume that the period utility function is given by

$$
u(c,\ell) = \frac{c^{1-\gamma}}{1-\gamma} - \frac{\ell^{1+1/\varphi}}{1+1/\varphi}.
$$

 (1)

The parameter γ is the coefficient of relative risk aversion and ϕ is the Frisch elasticity of labor supply. The corresponding HJB equation is

$$
\rho v_j(a) = \max_{c,\ell} u(c,\ell) + v_j'(a)(wz_j\ell + ra - c) + \lambda_j(v_{-j}(a) - v_j(a)), \quad j = 1, 2
$$

on (a,∞) and with a state-constraint boundary condition

$$
v_j'(\underline{a}) \ge u_c(wz_j\ell_j(\underline{a}) + r\underline{a}, \ell_j(\underline{a})) \quad \Rightarrow \quad v_j'(\underline{a}) \ge (wz_j\ell_j(\underline{a}) + r\underline{a})^{-\gamma}
$$

 (2)

The first-order conditions are

$$
u_c(c_j(a), \ell_j(a)) = v'_j(a),
$$

$$
-u_\ell(c_j(a), \ell_j(a)) = v'_j(a)wz_j.
$$

Dividing the latter by the former leads to the usual intra-temporal first-order condition

$$
-\frac{u_{\ell}(c_j(a), \ell_j(a))}{u_c(c_j(a), \ell_j(a))} = wz_j
$$

With the utility function (1) we have

$$
\ell_j(a)^{1/\varphi}c_j(a)^{\gamma} = wz_j \tag{3}
$$

### 2 Algorithm

See http://www.princeton.edu/~moll/HACTproject/labor\_supply.m which calls the subroutine http://www.princeton.edu/~moll/HACTproject/lab\_solve.m. We use an implicit, upwind finite-difference scheme. The algorithm is almost identical to that explained in Section 1 of http://www.princeton.edu/~moll/HACTproject/HACT\_Numerical\_Appendix.pdf and implemented in http://www.princeton.edu/~moll/HACTproject/HJB\_stateconstraint\_implicit. m. There is one tricky issue, namely how to impose the state constraint a ≥ a. And related, how to handle points at which the drift of wealth is zero (at which the upwind scheme switches between using forward and backward finite difference approximations to the derivative v 0 j (a)).

Consider first the state constraint at a = a and the associated boundary condition (2). Furthermore, consider the case where this constraint binds, i.e. (2) holds with equality. The difficulty is that labor supply `<sup>j</sup> (a) depends on consumption c<sup>j</sup> (a) itself, see (3). We therefore need to solve for <sup>`j`</sup>` (a) implicitly. In particular, we solve (3) at a = a and with c`<sup>`j`</sup>` (a) = wz`<sup>`j`</sup>` ``<sup>`j`</sup>` (a) + ra, that is, we solve

$$
\ell_j(\underline{a})^{1/\varphi}(wz_j\ell_j(\underline{a}) + r\underline{a})^{\gamma} = wz_j.
$$

This can be easily achieved, for example by using the Matlab function fzero. Once this equation is solved for, the state constraint boundary condition (2) can be imposed exactly like in the problem without labor supply in http://www.princeton.edu/~moll/HACTproject/ HACT\_Numerical\_Appendix.pdf

Other points in the state space at which the drift of wealth s`<sup>`j`</sup>` (a) = wz`<sup>`j`</sup>` ``<sup>`j`</sup>` (a) + ra − c`<sup>`j`</sup>` (a) is zero are handled in an analogous fashion. Importantly, this problem is independent of the current guess for the value function. One can therefore solve it once for every point in the state space before iterating on the value function.

## 3 Results

Figure 1 plots the consumption and policy functions. As expected, labor supply is higher for more productive individuals `2(a) > `1(a) for all a and is decreasing in wealth due to the standard wealth effect stemming from separable preferences like (1).

![](_page_2_Figure_0.jpeg)

Figure 1: Value and Policy Functions

## References

Achdou, Y., J. Han, J.-M. Lasry, P.-L. Lions, and B. Moll (2017): "Income and Wealth Distribution in Macroeconomics: A Continuous-Time Approach," NBER Working Papers 23732, National Bureau of Economic Research, Inc.
